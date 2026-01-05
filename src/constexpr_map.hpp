#pragma once
#include <array>
#include <algorithm>


/*
	This class should be used for small-ish data sets( maybe < 20) to implement a compile time map. Despite it doing 
	a liniar search with std::find_if , if used , for example , with string_view(to use string literals) , the compiler 
	greatly optimises the search and makes it 10x faster than a regular map.

        The guy I stole this from: https://www.youtube.com/watch?v=INn3xa4pMfg
*/

template<typename Key , typename Value , size_t Size>
struct constexpr_map{
        std::array<std::pair<Key, Value>, Size> data;
        [[nodiscard]] constexpr auto at(const Key& key) const noexcept {
                return std::find_if(std::begin(data), std::end(data), [key](const auto& pair) {
                        return pair.first == key;
                        });
        }
        [[nodiscard]] constexpr auto end() const noexcept {
                return std::end(data);
        }
        [[nodiscard]] constexpr bool exists(const Key& key) const noexcept {
                auto it = std::find_if(std::begin(data), std::end(data), [key](const auto& pair) {
                        return pair.first == key;
                });

                return it != std::end(data);
        }
};
