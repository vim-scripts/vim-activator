/*
 * File Name  : VimActivator.c
 * Author     : yiuwing
 * Created    : 2011-03-17 11:52:18
 * Stage      : Maintenance
 * Copyright  : Totally Free
 *
 */

#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>

#define PORT 6543
#define SEPARATOR ""
#define TESTING_PILL "3333 dummy"
 
/** 
 * @brief Open a connection and send the query to the server.
 * 
 * @param argv The second elemest is $$(PPID) and the third element is the
 * file name.
 *
 * @return 1 if we can connect to the server, otherwise 0.
 */
int doClient(char **argv)
{
	int sock = 0;
	if((sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
	{
		perror("Can't create TCP socket");
		exit(EXIT_FAILURE);
	}

	struct sockaddr_in *remote = (struct sockaddr_in *)malloc(sizeof(struct sockaddr_in *));
	remote->sin_family = AF_INET;

	int temp = inet_pton(AF_INET, "127.0.0.1", (void *)(&(remote->sin_addr.s_addr)));
	remote->sin_port = htons(PORT);
	if(connect(sock, (struct sockaddr *)remote, sizeof(struct sockaddr)) < 0)
	{
		// this is a test
		if (strcmp(*argv, TESTING_PILL) == 0)
			return 0;

		perror("Could not connect");
		exit(EXIT_FAILURE);
	}

	// Send the query to the server
	char *query = malloc(strlen(argv[1]) + strlen(argv[2]) + 4);
	sprintf(query, "%s%s%s\n", argv[1], SEPARATOR, argv[2]);
	int sent = 0;
	while(sent < strlen(query))
	{
		temp = send(sock, query + sent, strlen(query) - sent, MSG_DONTWAIT);
		if(temp == -1)
		{
			perror("Can't send query");
			exit(EXIT_FAILURE);
		}
		sent += temp;
	}

	free(remote);
	free(query);
	close(sock);

	return 1;
}

/** 
 * @brief Run the daemon in a loop that forwards request to real vim server.
 */
void runDaemon()
{
	char buffer[BUFSIZ];
	struct sockaddr_in serverAddress;

	int serverfd = socket(AF_INET, SOCK_STREAM, 0);
	if (serverfd < 0) 
		perror("ERROR opening socket");

	bzero((char *) &serverAddress, sizeof(serverAddress));
	serverAddress.sin_family      = AF_INET;
	serverAddress.sin_addr.s_addr = INADDR_ANY;
	serverAddress.sin_port        = htons(PORT);
	if (bind(serverfd, (struct sockaddr *) &serverAddress, sizeof(serverAddress)) < 0) 
		perror("ERROR on binding");

	listen(serverfd, 5);

	struct sockaddr_in clientAddress;
	socklen_t length = sizeof(clientAddress);
	/* The big loop */
	while (1)
	{
		int clientfd = accept(serverfd, (struct sockaddr *) &clientAddress, &length);
		if (clientfd < 0) 
			perror("ERROR on accept");

		bzero(buffer, BUFSIZ);
		int n = read(clientfd, buffer, BUFSIZ - 1);
		if (n < 0) 
			perror("ERROR reading from socket");

		/* printf("Here is the message: %s\n",buffer); */
		char *ppid = strtok(buffer, SEPARATOR);
		/* printf("ppid: %s\n", ppid); */
		char *filename = strtok(NULL, SEPARATOR);
		/* printf("filename: %s\n", filename); */

		char *command = "/usr/bin/vim --servername VIM%s -u NONE -U NONE --remote-send \"<C-\\><C-N>:n<Space>%s<CR>\"";
		int temp = strlen(command) + strlen(ppid) + strlen(filename) + 1;
		char *request = malloc(temp);
		snprintf(request, temp, command, ppid, filename);
		system(request);
		free(request);
		close(clientfd);
	}

	close(serverfd);
}

/** 
 * @brief Start the forwarding server if needed.
 */
void doServer()
{
	char *temp = TESTING_PILL;
	// the server has already been started
	if (doClient(&temp))
		return;

	/* Our process ID and Session ID */
	pid_t pid, sid;
	/* Fork off the parent process */
	pid = fork();
	if (pid < 0) 
		exit(EXIT_FAILURE);

	/* If we got a good PID, then we can exit the parent process. */
	if (pid > 0)
		exit(EXIT_SUCCESS);

	/* Change the file mode mask */
	umask(0);

	/* Create a new SID for the child process */
	sid = setsid();
	if (sid < 0)
		exit(EXIT_FAILURE);

	/* Close out the standard file descriptors */
	close(STDIN_FILENO);
	close(STDOUT_FILENO);
	close(STDERR_FILENO);

	/* Daemon-specific initialization goes here */
	runDaemon();
	exit(EXIT_SUCCESS);
}

/** 
 * @brief This program can act as the client or server that forwards request to vim
 * server.
 * 
 * compile this program
 *
 * gcc -Wall -g -o activator VimActivator.c
 *
 * @param argc If its 1 then start the server, otherwise act as a
 * client and send the message in args[0] to the server.
 */
int main(int argc, char **argv) 
{
	if(argc == 1)
		doServer();
	else if (argc == 3)
		doClient(argv);
	else
		exit(EXIT_FAILURE);

	return 0;
}
