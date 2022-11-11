(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using STBV1
const UserApp = STBV1
STBV1.main()
