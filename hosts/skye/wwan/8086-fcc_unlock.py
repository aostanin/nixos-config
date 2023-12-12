import hashlib
import sys

salt = {
        '8086:7560': b"\xbb\x23\xbe\x7f",
        '8086:4d75': b"\x74\xde\xbb\xa9"
        # ???: \xcc\xa6\x1d\xdf"
}

log = open("/tmp/fcc", "w")
log.write(str(sys.argv) + "\n")

devid = sys.argv[0].split('/')[-1]
dbusd = sys.argv[1]
ctldevs = sys.argv[2:]

# FIXME
ctldev = 'wwan0at0'


def read_to_cr(c):
    data = c.readline()
    nocr = data.strip(b'\r\n')
    if nocr == b'':
        return read_to_cr(c)
    print(f'response from modem: {nocr.decode("utf-8")}')
    log.write(f'response from modem: {nocr.decode("utf-8")}')
    if nocr == b'ERROR':
        sys.exit(1)
    return nocr


def query_modem(c, query):
    print(f'query modem: {query.decode("utf-8")}')
    log.write(f'query modem: {query.decode("utf-8")}')
    c.write(query)
    res = read_to_cr(c)
    if res != b'OK':
        read_to_cr(c)
    return res


log.write("1\n")
with open(f'/dev/{ctldev}', 'r+b', buffering=0) as c:
    log.write("2\n")
    locked = query_modem(c, b'at+gtfcclockstate\r')
    log.write("2a\n")
    if locked == b'1':
        log.write("2b\n")
        sys.exit(0)

    # > at+gtfcclockgen
    # < 0x12345678 (a challenge, some eight-digit hex string)
    log.write("3\n")
    challenge = query_modem(c, b'at+gtfcclockgen\r')

    log.write("4\n")
    challenge = int(challenge, 16).to_bytes(4, byteorder='little')
    to_hash = challenge + salt[devid]

    log.write("5\n")
    m = hashlib.sha256()
    m.update(to_hash)
    res = str(int.from_bytes(m.digest()[:4], byteorder='little'))

    log.write("6\n")
    # > at+gtfcclockver=1927859199
    # < OK
    query_modem(c, b'at+gtfcclockver=' + res.encode('utf-8') + b'\r')
    # > at+gtfcclockmodeunlock
    # < OK
    log.write("7\n")
    query_modem(c, b'at+gtfcclockmodeunlock\r')
    # > at+cfun=1
    # < OK
    log.write("8\n")
    query_modem(c, b'at+cfun=1\r')
    # > at+gtfcclockstate
    # < 1
    # <
    # < OK
    log.write("9\n")
    locked = query_modem(c, b'at+gtfcclockstate\r')
    if locked == b'1':
        log.write("10\n")
        sys.exit(0)

log.write("11\n")
sys.exit(1)
