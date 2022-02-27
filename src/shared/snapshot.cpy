namespace framebuffer:
  class Snapshot:
    typedef uint64_t chunk_t;

    struct RLEBlock:
      uint32_t count
      chunk_t value

      known RLEBlock(uint32_t c, chunk_t v):
        count = c
        value = v
    ;

    vector<RLEBlock> encoded

    public:
    int rotation
    int bits_per_pixel

    Snapshot(int w, h):
      fb := framebuffer::get()
      bits_per_pixel = fb->get_screen_depth()
      bytes_per_pixel := bits_per_pixel / 8
      bytes := (uint32_t) w * h * bytes_per_pixel / sizeof(chunk_t)

      chunk_t white_pixel = -1;
      encode_values(encoded, bytes, white_pixel)

    ~Snapshot():
      pass

    inline void encode_values(vector<RLEBlock> &encoded, uint32_t count, chunk_t value):
      encoded.emplace_back(count, value)

    void save_bpp():
      fb := framebuffer::get()
      bits_per_pixel = fb->get_screen_depth()

    void compress(remarkable_color *in, int bytes):
      ClockWatch cz
      uint32_t count

      encoded.clear()
      encoded.reserve(100000)

      chunk_t *src = (chunk_t*) in
      chunk_t cur
      chunk_t prev = src[0]


      count = 0
      int size = 0
      int n = bytes/sizeof(chunk_t)
      for i := 0; i < n; i++:
        if unlikely(src[i] != prev):
          encode_values(encoded, count, prev)
          count = 1
          prev = src[i]
        else:
          count++

      encode_values(encoded, count, prev)

      size = sizeof(encoded[0]) * encoded.size()
      debug "COMP TOOK", cz.elapsed(), "TOTAL SIZE", (size/1024), "KBYTES,", encoded.size(), "ELEMENTS"

    decompress(remarkable_color *out):
      ClockWatch cz
      chunk_t *src = (chunk_t*) out
      int offset = 0
      for auto &block : encoded:
        for i := 0; i < block.count; i++:
          src[i+offset] = block.value

        offset += block.count
      debug "DECOMP TOOK", cz.elapsed()


    void allocate():
      pass

