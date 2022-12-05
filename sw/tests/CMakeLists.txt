add_executable(TestSudaAPI TestSudaAPI.cpp)
target_link_libraries(TestSudaAPI sudart suda)

add_executable(TestSuFile TestSuFile.cpp)
target_link_libraries(TestSuFile sudart suda sufile)