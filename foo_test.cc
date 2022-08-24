#include "foo.h"

#include <gtest/gtest.h>

TEST(Foo, Simple) { EXPECT_EQ(1 + 1, 2); }

TEST(Foo, Magic) {
  Foo dut;
  EXPECT_EQ(dut.Bar(), 42);
}