import os
import time
import shutil
from django.conf import settings

def check_and_get_video_type(type_obj, type_value, message):
    try:
        type_obj(type_value)
    except:
        return {'code': -1, 'msg': message}

    return {'code': 0, 'msg': 'success'}



def hanle_video(video_file, video_id, number):
    in_path = os.path.join(settings.BASE_DIR, 'app/dashboard/temp_in')
    out_path = os.path.join(settings.BASE_DIR, 'app/dashboard/temp_out')
    name = '{}_{}'.format(int(time.time()), video_file.name)
    in_path_name = '/'.join([in_path, name])

    temp_path = video_file.temporary_file_path()
    shutil.copyfile(temp_path, in_path_name)

    out_path_name = '/'.join([out_path, video_file.name.split('.')[0]])
    command='ffmpeg -i {} -c copy {}.mp4'.format(in_path_name, out_path_name)
    os.system(command)
    return True