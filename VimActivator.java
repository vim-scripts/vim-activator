/*
 * File Name  : VimActivator.java
 * Authors    : yiuwing*
 * Created    : 2011-03-16 14:48:38
 * Stage      : Prototype
 * Copyright  : Copyright © 2011 OneCloud Co., Ltd.  All rights reserved.
 *
 * This software is the confidential and proprietary information of 
 * OneCloud Co., Ltd. ("Confidential Information").  You shall not
 * disclose such Confidential Information and shall use it only in
 * accordance with the terms of the license agreement you entered into
 * with OneCloud.
 */

import java.io.*;
import java.net.*;

/** 
 * A util class for working with vim remote feature.
 * 
 */
public class VimActivator
{
	/** 
	 * The listening port number.
	 */
	private static final int LISTENING_PORT = 6543;

	/** 
	 * The separator between PPID($$) and file name.
	 */
	private static final String SEPARATOR = "";

	/** 
	 * Start the server.
	 */
	private static final void doServer()
		throws IOException
	{
		ServerSocket server = new ServerSocket(LISTENING_PORT);
		while (true)
		{
			Socket client = server.accept();

			try
			{
				LineNumberReader reader = new LineNumberReader(new InputStreamReader(client.getInputStream()));
				String line = reader.readLine();
				if (line == null)
					continue;

				// wait a little bit
				Thread.sleep(25);

				String temp[] = line.split(SEPARATOR);
				if (temp.length != 2)
					continue;

				// use <Space> to enter a white space " ".
				String command = "/usr/bin/vim --servername VIM" + temp[0] + " -u NONE -U NONE " +
								 "--remote-send <C-\\><C-N>:n<Space>" + temp[1] + "<CR>";
				System.out.println(command);
				Process process = Runtime.getRuntime().exec(command);
				/* process.waitFor(); */
			}
			catch (Throwable igonre)
			{
				; // empty
			}
		}
	}

	/** 
	 * Start a client and send the message to the server.
	 */
	private static final void doClient(String message)
		throws IOException
	{
		Socket socket = new Socket("localhost", LISTENING_PORT);
		PrintStream writer = new PrintStream(socket.getOutputStream());
		writer.println(message);
	}

	/** 
	 * The program entry point.
	 * 
	 * @param args If its empty then start the server, otherwise act as a
	 * client and send the message in args[0] to the server.
	 */
	public static final void main(String args[])
	{
		try
		{
			if (args.length == 0)
				doServer();
			else
				doClient(args[0] + SEPARATOR + args[1]);
		}
		catch (Throwable ignore)
		{
			// notify the shell script there's error
			System.exit(1);
		}
	}
}
