import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
import math
import os
import copy


# Function that returns the number in the filename the preceeds the string 'fps'
def get_framerate(filename):
    i = 0
    framerate = 30
    for x in range(0, len(filename)):
        if filename[x] == "f" and filename[x+1] == "p" and filename[x+2] == "s":
            while filename[x - i] != "_":
                i += 1
                framerate = filename[x - i + 1:x]
        framerate = int(math.floor(float(framerate)))
    return framerate


# Function that returns the magnetic field strength in the filename the preceeds the string 'mT'
def get_b(filename):
    i = 0
    b = 0
    for x in range(0, len(filename)):
        if filename[x] == "m" and filename[x+1] == "t":
            while filename[x - i] != "_":
                i += 1
                b = filename[x - i + 1:x]
    return b


# Function to check if the datafile is directly from ImageJ's Mosaic plugin
def check_tracker(df):
    try:
        if df.iloc[0][1] == "Spot ID":
            tracker = "TrackMate"
    except:
        tracker = "Mosaic"
    else:
        tracker = "TrackMate"
    return tracker


# Function gets rid of unneeded columns and cleans up the dataframe
def clean_df(df, tracker):
    if tracker == "TrackMate":
        df_new = df.iloc[3:]
        df_new = df_new.rename({'POSITION_X': 'x', 'POSITION_Y': 'y', 'FRAME':'Frame', 'TRACK_ID':'Trajectory'}, axis='columns')
        df_new = pd.concat([df_new['Trajectory'].astype(float), df_new['x'].astype(float), df_new['y'].astype(float), df_new['Frame'].astype(int)], axis=1)
        df_new = df_new.sort_values('Frame', ascending=True)
    else:
        df_new = pd.concat([df['Trajectory'], df['x'], df['y'], df['Frame']])
    return df_new


# Function that takes out any trajcetories below a certain threshold
def trim_trajectories(df, frame_threshold_count):
    x_pos, y_pos = {}, {}
    for trajectory in range(1, df['Trajectory'].nunique() + 1):
        if len(df.loc[df['Trajectory'] == trajectory]) > frame_threshold_count:
            x_pos.update({trajectory: df['x'].loc[(df['Trajectory'] == trajectory)]})
            y_pos.update({trajectory: df['y'].loc[(df['Trajectory'] == trajectory)]})
    return x_pos, y_pos


# Displays the trajectory along with its speed, heading, and heading std
def show_trajectory_debug(x_pos, y_pos, trajectory, fpra, speed_fraction, heading_std_threshold):

    speed = speed_roll(x_pos, y_pos, 1, trajectory)
    heading = heading_roll(x_pos, y_pos, 1 , trajectory)
    heading_std = heading_std_roll(x_pos, y_pos, 1, trajectory)

    rolled_x_pos, rolled_y_pos = roll(x_pos, y_pos, fpra, trajectory)
    rolled_speed = speed_roll(x_pos, y_pos, fpra, trajectory)
    rolled_heading = heading_roll(x_pos, y_pos, fpra, trajectory)
    rolled_heading_std = heading_std_roll(x_pos, y_pos, fpra, trajectory)

    fig = plt.figure()
    gs = GridSpec(2, 2, figure=fig)

    ax1 = fig.add_subplot(gs[0, 0])
    ax1.set_xlabel("X (pixels)")
    ax1.set_ylabel("Y (pixels)")
    ax1.text(list(x_pos[trajectory])[0], list(y_pos[trajectory])[0], "Start")
    ax1.plot(x_pos[trajectory], y_pos[trajectory], label="original data")
    ax1.plot(rolled_x_pos, rolled_y_pos, label="rolled data")
    plt.legend(fontsize='x-small')

    ax2 = fig.add_subplot(gs[0, 1])
    ax2.set_xlabel("Tick")
    ax2.set_ylabel("Speed (pixels/tick)")
    ax2.plot(range(len(speed)), speed, label='normal')
    ax2.plot(range(len(rolled_speed)), rolled_speed, color='black', label='rolling')
    ax2.hlines(speed_fraction*np.median(rolled_speed), 0, len(rolled_speed), linestyles='--', label='median r-speed', color='black')
    plt.legend(fontsize='x-small')

    ax3 = fig.add_subplot(gs[1, 0])
    ax3.set_xlabel("Tick")
    ax3.set_ylabel("Heading")
    ax3.plot(range(len(heading[0])), heading[0], label='x')
    ax3.plot(range(len(heading[0])), heading[1], label='y')
    ax3.plot(range(len(rolled_heading[0])), rolled_heading[0], label='x-roll')
    ax3.plot(range(len(rolled_heading[1])), rolled_heading[1], label='y-roll')
    plt.legend(fontsize='x-small')

    ax4 = fig.add_subplot(gs[1, 1])
    ax4.set_xlabel("Tick")
    ax4.set_ylabel("Heading STD")
#         ax4.plot(range(len(heading_std)), heading_std, label='std')
    ax4.plot(range(len(rolled_heading_std)), rolled_heading_std, label='std_roll')
    ax4.hlines(heading_std_threshold, 0, len(rolled_heading_std), linestyles='--', label='median roll_head', color='black')
    plt.legend(fontsize='x-small')

    fig.suptitle("Trajectory " + str(trajectory) + ", " + str(filename[0:-4]))

    plt.show()
    return


# Displays the trajectory along with its speed, heading, and heading std
def show_trajectory(filename, traj, fpra=1, heading_std_threshold=0.4, speed_fraction=0.66):
    df = pd.read_csv(filename, encoding='utf-8', low_memory=False)
    df = clean_df(df, check_tracker(df))
    x_pos, y_pos = trim_trajectories(df, 0)

    speed = speed_roll(x_pos, y_pos, 1, traj)
    heading = heading_roll(x_pos, y_pos, 1, traj)
    heading_std = heading_std_roll(x_pos, y_pos, 1, traj)

    rolled_x_pos, rolled_y_pos = roll(x_pos, y_pos, fpra, traj)
    rolled_speed = speed_roll(x_pos, y_pos, fpra, traj)
    rolled_heading = heading_roll(x_pos, y_pos, fpra, traj)
    rolled_heading_std = heading_std_roll(x_pos, y_pos, fpra, traj)

    fig = plt.figure()
    gs = GridSpec(2, 2, figure=fig)

    ax1 = fig.add_subplot(gs[0, 0])
    ax1.set_xlabel("X (pixels)")
    ax1.set_ylabel("Y (pixels)")
    ax1.text(list(x_pos[traj])[0], list(y_pos[traj])[0], "Start")
    ax1.plot(x_pos[traj], y_pos[traj], label="original data")
    ax1.plot(rolled_x_pos, rolled_y_pos, label="rolled data")
    plt.legend(fontsize='x-small')

    ax2 = fig.add_subplot(gs[0, 1])
    ax2.set_xlabel("Tick")
    ax2.set_ylabel("Speed (pixels/tick)")
    ax2.plot(range(len(speed)), speed, label='normal')
    ax2.plot(range(len(rolled_speed)), rolled_speed, color='black', label='rolling')
    ax2.hlines(speed_fraction * np.median(rolled_speed), 0, len(rolled_speed), linestyles='--', label='fraction of median r-speed',
               color='black')
    plt.legend(fontsize='x-small')

    ax3 = fig.add_subplot(gs[1, 0])
    ax3.set_xlabel("Tick")
    ax3.set_ylabel("Heading")
#     ax3.plot(range(len(heading[0])), heading[0], label='x')
#     ax3.plot(range(len(heading[0])), heading[1], label='y')
    ax3.plot(range(len(rolled_heading[0])), rolled_heading[0], label='x-roll')
    ax3.plot(range(len(rolled_heading[1])), rolled_heading[1], label='y-roll')
    plt.legend(fontsize='x-small')

    ax4 = fig.add_subplot(gs[1, 1])
    ax4.set_xlabel("Tick")
    ax4.set_ylabel("Heading STD")
    ax4.plot(range(len(rolled_heading_std)), rolled_heading_std, label='std_roll')
    ax4.hlines(heading_std_threshold, 0, len(rolled_heading_std), linestyles='--',
               label='heading_std_threshold', color='black')
    ax4.hlines(np.median(rolled_heading_std), 0, len(rolled_heading_std), linestyles='--',
               label='median std', color='red')
    plt.legend(fontsize='x-small')

    fig.suptitle("Trajectory " + str(traj) + ", " + str(filename[0:-4]))

    plt.show()

    return


def roll(x, y, ffpra, traj):
    new_x_pos = []
    new_y_pos = []
    rolls = math.floor(len(x[traj]) / ffpra)
    for m in range(rolls):
        new_x_pos.append(np.average(x[traj][ffpra*m:ffpra*(m+1)]))
        new_y_pos.append(np.average(y[traj][ffpra*m:ffpra*(m+1)]))
    return new_x_pos, new_y_pos


def speed_roll(x, y, ffpra, traj):
    new_speed = []
    x, y = roll(x, y, 1, traj)
    rolls = math.floor(len(x) / ffpra)
    for m in range(len(x)-1):
        x_speed = x[m+1] - x[m]
        y_speed = y[m+1] - y[m]
        new_speed.append(np.sqrt(x_speed**2 + y_speed**2))
    if ffpra > 1:
        roll_speed = []
        for k in range(len(new_speed)-ffpra):
            roll_speed.append(np.average(new_speed[k:k+ffpra]))
#         for n in range(rolls):
#             roll_speed.append(np.average(new_speed[ffpra*n:ffpra*(n+1)]))
        new_speed = copy.copy(roll_speed)
    return new_speed


def heading_roll(x, y, ffpra, traj):
    heading = []
    x_direction = []
    y_direction = []
    heading_vector_x = []
    heading_vector_y = []
    x, y = roll(x, y, 1, traj)
    for n in range(len(x)-1):
        heading_vector_x.append(x[n+1] - x[n])
        heading_vector_y.append(y[n+1] - y[n])
    heading_vector = [heading_vector_x, heading_vector_y]
    rolls = math.floor(len(heading_vector[0]) / ffpra)
    for m in range(len(heading_vector[0])-ffpra):
        x_direction.append((1/np.pi)*np.arccos(np.average(heading_vector[0][m:m+ffpra])/np.sqrt(np.average(heading_vector[0][m:m+ffpra])**2+np.average(heading_vector[1][m:m+ffpra])**2)))
        y_direction.append((1/np.pi)*np.arccos(np.average(heading_vector[1][m:m+ffpra])/np.sqrt(np.average(heading_vector[0][m:m+ffpra])**2+np.average(heading_vector[1][m:m+ffpra])**2)))
    heading.append(x_direction)
    heading.append(y_direction)
    return heading


def get_heading(x, y):
    x_direction = (1/np.pi)*np.arccos(x/np.sqrt(x**2+y**2))
    y_direction = (1/np.pi)*np.arccos(y/np.sqrt(x**2+y**2))
    heading = [x_direction, y_direction]
#     print(str(heading[0]) + " degrees off from right " + str(heading[1]) + "degrees off from up")
    return heading


def get_all_headings(vel_x_pos, vel_y_pos):
    heading_x = []
    heading_y = []
    heading_total = []
    for k in range(len(vel_x_pos)-1):
        vector_1 = [(vel_x_pos[k+1] - vel_x_pos[k]), (vel_y_pos[k+1] - vel_y_pos[k])]
        vel_heading = get_heading(vector_1[0], vector_1[1])
        heading_x.append(vel_heading[0])
        heading_y.append(vel_heading[1])
    heading_total.append(heading_x)
    heading_total.append(heading_y)

    return heading_total


def heading_std_roll(x, y, ffpra, trajectory):
    x, y = roll(x, y, 1, trajectory)
    heading_total = get_all_headings(x, y)
    rolling_std = []
    for k in range(np.shape(heading_total)[1]-ffpra):
        x_std = np.std(heading_total[0][k:k+ffpra])
        y_std = np.std(heading_total[1][k:k+ffpra])
        rolling_std.append(x_std+y_std)
    return rolling_std


def classify(tumbling, reversing, uturning):
    result = 'na'
    if tumbling:
        result = 'tumble'
        return result
    if reversing:
        result = 'reverse'
        return result
    if uturning:
        result = 'uturn'
        return result
    return result


def debug(event_slowing, event_directions_swap, event_changing_direction, slowed, prolonged_changing_direction):
    print("Event Slowing: " + str(event_slowing))
    print("Event Directions Swap: " + str(event_directions_swap))
    print("Event Changing Direction: " + str(event_changing_direction))
    print("Event Slowed: " + str(slowed))
    print("Prolonged Changing Direction: " + str(prolonged_changing_direction))
    return


def plot_event_history(tumble_length_history):
    fig = plt.figure()
    gs = GridSpec(1, 1, figure=fig)
    ax1 = fig.add_subplot(gs[0, 0])
    ax1.set_xlabel("Seconds")
    ax1.set_ylabel("Frequency")
    ax1.hist(tumble_length_history)
    fig.suptitle("Tumble length n=(" + str(len(tumble_length_history)) + ")")
    plt.show()
    return


def get_events(filedir, fpra, frame_threshold_count, heading_std_threshold=0.5, speed_fraction=0.66, framerate=0, write=False,
               debugprints=False):

    # A few exceptions that will raises a ValueError--these are to prevent unwanted variable inputs
    if isinstance(fpra, str) or isinstance(fpra, float) or fpra < 0:
        raise ValueError("FPRA must be a positive integer")

    if isinstance(frame_threshold_count, str) or isinstance(fpra, float) or fpra < 0:
        raise ValueError("frame_threshold_count must be a positive integer")

    if isinstance(heading_std_threshold, str) or heading_std_threshold > 2 or heading_std_threshold < 0:
        raise ValueError("heading_std_threshold must be a float between 0 and 2")

    if isinstance(speed_fraction, str) or speed_fraction > 1 or speed_fraction < 0:
        raise ValueError("speed_fraction must be a float between 0 and 1")

    if fpra > frame_threshold_count:
        raise ValueError("frame_threshold_count must be greater than the FPRA.")

    # Collect all of the CSV files from the list and delete ".DS_Store", a common hidden file made automatically with MacOS
    files = os.listdir(filedir)
    if files.count(".DS_Store") > 0:
        files.remove(".DS_Store")
    tumble_length_history = {}

    # If the 'write' variable is true, then it will create a csv file and output results from all csv files there
    if write:
        f = open(filedir + "/MTB_Events_Results.csv", "w")
        f.write(
            "filename,fpra,total_time,num_revs,prob_of_rev(%),num_tumbles,prob_of_tumble(%),frame_threshold_count,framerate")

    pcd_history = {}
    for filename in files:

        tumbles, reverses, result = 0, 0, 'na'

        # Grabbing and organizing the data from source csv file
        file = filedir + "/" + filename
        framerate = get_framerate(filename)
        if framerate <= 0:
                raise ValueError("Framerate must be stated in function or must be incorporated in filename (e.g.\'exdata_323fps_001.csv\' ")

        # Read csv file
        df = pd.read_csv(file, encoding='utf-8', low_memory=False)
        df = clean_df(df, check_tracker(df))
        if check_tracker(df) == "Mosaic":
            x_pos, y_pos = trim_trajectories(df, frame_threshold_count)
        else:
            x_pos, y_pos = trim_trajectories(df, frame_threshold_count)

        for trajectory in x_pos:

            trajectory_events = []

            speed = speed_roll(x_pos, y_pos, 1, trajectory)
            heading = heading_roll(x_pos, y_pos, 1, trajectory)
            heading_std = heading_std_roll(x_pos, y_pos, 1, trajectory)

            rolled_x_pos, rolled_y_pos = roll(x_pos, y_pos, fpra, trajectory)
            rolled_speed = speed_roll(x_pos, y_pos, fpra, trajectory)
            rolled_heading = heading_roll(x_pos, y_pos, fpra, trajectory)
            rolled_heading_std = heading_std_roll(x_pos, y_pos, fpra, trajectory)

            directions_swap = False
            event_directions_swap = False
            slowing = False
            event_slowing = False
            changing_direction = False
            event_changing_direction = False
            prolonged_changing_direction = False
            switch = False
            event_switch = False
            tumbling = False
            reversing = False
            uturning = False
            slowed = False
            swapped = False

            for k in range(5, len(rolled_speed) - 2):

                # If directions are swapped
                if (rolled_heading[0][k] > rolled_heading[1][k] and rolled_heading[0][k + 1] < rolled_heading[1][
                    k + 1]) or \
                        (rolled_heading[0][k] < rolled_heading[1][k] and rolled_heading[0][k + 1] > rolled_heading[1][
                            k + 1]) and \
                        (np.abs(rolled_heading[0][k + 1] - rolled_heading[1][k + 1]) > 0.05):
                    if directions_swap:
                        swapped = True
                    directions_swap = True
                    event_directions_swap = True
                else:
                    directions_swap = False
                # If the heading std is 3 times larger than the average
                if rolled_speed[k] < speed_fraction * np.median(rolled_speed):
                    slowing = True
                    if event_slowing:
                        slowed = True
                        if pcd_history.get(trajectory) is None:
                            pcd_history.update({trajectory: 1})
                        else:
                            pcd_history.update({trajectory: pcd_history.get(trajectory) + 1})
                    else:
                        event_slowing = True
                else:
                    slowing = False

                # If large change in heading standard deviation
                if rolled_heading_std[k] > heading_std_threshold:
                    changing_direction = True
                    if event_changing_direction:
                        prolonged_changing_direction = True
                        if pcd_history.get(trajectory) is None:
                            pcd_history.update({trajectory: 1})
                        else:
                            pcd_history.update({trajectory: pcd_history.get(trajectory) + 1})
                    else:
                        event_changing_direction = True
                else:
                    changing_direction = False

                if not directions_swap and not changing_direction and not slowing:
                    if (slowed and prolonged_changing_direction) and pcd_history.get(trajectory) > 1:
                        tumbling = True
                        if debugprints:
                            print("----- Tumble at tick " + str(k) + " -----")
                            debug()
                        event_slowing, event_directions_swap, event_changing_direction, slowed, prolonged_changing_direction = False, False, False, False, False
                    elif (event_slowing and event_changing_direction):
                        reversing = True
                        if debugprints:
                            print("----- Reverse at tick " + str(k) + " -----")
                            debug()
                        event_slowing, event_directions_swap, event_changing_direction, slowed, prolonged_changing_direction = False, False, False, False, False
                    elif event_directions_swap and not (event_changing_direction or event_slowing):
                        #                         uturning = True
                        event_slowing, event_directions_swap, event_changing_direction, slowed, prolonged_changing_direction = False, False, False, False, False
                    result = classify(tumbling, reversing, uturning)
                    if result == 'tumble':
                        trajectory_events.append('tumble')
                    if result == 'reverse':
                        trajectory_events.append('reverse')
                    if result == 'uturn':
                        trajectory_events.append('uturn')
                    tumbling = False
                    reversing = False
                    uturning = False

            # Count up all the tumbles and reverses found in the trajectory_events for this file
            tumbles += trajectory_events.count('tumble')
            reverses += trajectory_events.count('reverse')

            # If debugprints is true and there are events, show the trajectory's plots
            if debugprints and len(trajectory_events) > 0:
                print(str(trajectory) + ": " + str(trajectory_events))
                show_trajectory_debug(file, trajectory, fpra, heading_std_threshold, speed_fraction)

        # Calculate total number of frames by recursively adding all of the number of positions per MTB
        total_frames = 0
        for trajectory in x_pos:
            total_frames += len(x_pos[trajectory])

        # Calculate event probabilities by dividing by seconds ( framerate/total_frames ) and by the total number of trajectories for events per MTB per second
        prob_of_rev = (reverses * framerate) / (total_frames * len(x_pos))
        prob_of_tumble = (tumbles * framerate) / (total_frames * len(x_pos))

        if write:
            f.write("""
            """ + str(filename[0:-4]) + "," + str(fpra) + "," + str(total_frames / framerate) + "," + str(reverses) + "," + str(
                prob_of_rev*100) + "," + str(tumbles) + "," + str(prob_of_tumble)*100 + "," + str(
                frame_threshold_count) + "," + str(
                framerate))

        print("")
        print("--- " + filename + " completed. ---")
        print("Total MTB found: " + str(df['Trajectory'].nunique()) + ", Total MTB used: " + str(len(x_pos)))
        print("Total time of all trajectories analyzed: " + str(np.round(total_frames / framerate,2)) + " seconds")
        print(str(tumbles) + " tumbles and " + str(reverses) + " reverses found.")
        print("Probability of tumbling: " + str(np.round(prob_of_tumble*100,2)) + "% , Probablity of reversing: " + str(np.round(prob_of_rev*100,2)) + "%, per MTB per second")

    if write: f.close()

    # Convet tumble_length_history values from frames to seconds
    tumble_length_history = [x / framerate for x in pcd_history.values()]

    return tumble_length_history
