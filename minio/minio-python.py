from urllib3 import PoolManager
from urllib3 import Retry
from urllib3 import Timeout

from minio import Minio
from minio.error import ResponseError


status_list=(500, 502, 503, 504)

urllib3_retry = {
                 'total': 5,
                 'backoff_factor': 0.2,
                 'status_forcelist': status_list
                }

urllib3_poolmanager = {
                       'timeout': Timeout.DEFAULT_TIMEOUT,
                       'cert_reqs': 'CERT_REQUIRED',
                       'ca_certs': '/tmp/minio.crt',
                       'retries': Retry(**urllib3_retry)
                      }                              

http_client = PoolManager(**urllib3_poolmanager)

params_conn = {
          'endpoint': '192.168.56.2:9000',
          'access_key': '5D0EN4B8SF7EYUJH1V8I',
          'secret_key': 'BjtgRNuLHBSEUU4e2Yzz/lBVjoFVnIvCr6rGFRXo',
          'secure': True,
          'http_client': http_client
         }

conn = Minio(**params_conn)

try:
    conn.make_bucket('foo')

except BucketAlreadyOwnedByYou as err:
    pass

except BucketAlreadyExists as err:
    pass

except ResponseError as err:
    raise

else:
    # Put an object 'pumaserver_debug.log' 
    # with contents from 'pumaserver_debug.log'.
    try:
        conn.fput_object(
                         object_name='Bla_bla_bla.txt',
                         file_path='/tmp/blablabla.txt',
                         bucket_name='foo'
                        )

    except ResponseError as err:
        print(err)
