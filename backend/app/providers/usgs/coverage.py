import math

# OCHA COD MMR national extent, used to build the USGS request envelope.
MYANMAR_MIN_LATITUDE = 9.60588355699997
MYANMAR_MAX_LATITUDE = 28.545538862000058
MYANMAR_MIN_LONGITUDE = 92.17210485900011
MYANMAR_MAX_LONGITUDE = 101.17001505500019

# Include nearby border and offshore events without treating the buffer as an
# affected-area calculation.
COVERAGE_BUFFER_KM = 100.0

# The provider accepts a rectangular query only. These conservative bounds
# enclose the national outline and its 100 km buffer.
MIN_LATITUDE = 8.7
MAX_LATITUDE = 29.45
MIN_LONGITUDE = 91.1
MAX_LONGITUDE = 102.25

# Simplified Myanmar national outline based on the public country geometry at
# https://github.com/johan/world.geo.json/blob/master/countries/MMR.geo.json.
# Coordinates are (longitude, latitude); this geometry is only used for
# provider filtering, not for political, hazard, or safety conclusions.
MYANMAR_BOUNDARY: tuple[tuple[float, float], ...] = (
    (99.543309, 20.186598),
    (98.959676, 19.752981),
    (98.253724, 19.708203),
    (97.797783, 18.62708),
    (97.375896, 18.445438),
    (97.859123, 17.567946),
    (98.493761, 16.837836),
    (98.903348, 16.177824),
    (98.537376, 15.308497),
    (98.192074, 15.123703),
    (98.430819, 14.622028),
    (99.097755, 13.827503),
    (99.212012, 13.269294),
    (99.196354, 12.804748),
    (99.587286, 11.892763),
    (99.038121, 10.960546),
    (98.553551, 9.93296),
    (98.457174, 10.675266),
    (98.764546, 11.441292),
    (98.428339, 12.032987),
    (98.509574, 13.122378),
    (98.103604, 13.64046),
    (97.777732, 14.837286),
    (97.597072, 16.100568),
    (97.16454, 16.928734),
    (96.505769, 16.427241),
    (95.369352, 15.71439),
    (94.808405, 15.803454),
    (94.188804, 16.037936),
    (94.533486, 17.27724),
    (94.324817, 18.213514),
    (93.540988, 19.366493),
    (93.663255, 19.726962),
    (93.078278, 19.855145),
    (92.368554, 20.670883),
    (92.303234, 21.475485),
    (92.652257, 21.324048),
    (92.672721, 22.041239),
    (93.166128, 22.27846),
    (93.060294, 22.703111),
    (93.286327, 23.043658),
    (93.325188, 24.078556),
    (94.106742, 23.850741),
    (94.552658, 24.675238),
    (94.603249, 25.162495),
    (95.155153, 26.001307),
    (95.124768, 26.573572),
    (96.419366, 27.264589),
    (97.133999, 27.083774),
    (97.051989, 27.699059),
    (97.402561, 27.882536),
    (97.327114, 28.261583),
    (97.911988, 28.335945),
    (98.246231, 27.747221),
    (98.68269, 27.508812),
    (98.712094, 26.743536),
    (98.671838, 25.918703),
    (97.724609, 25.083637),
    (97.60472, 23.897405),
    (98.660262, 24.063286),
    (98.898749, 23.142722),
    (99.531992, 22.949039),
    (99.240899, 22.118314),
    (99.983489, 21.742937),
    (100.416538, 21.558839),
    (101.150033, 21.849984),
    (101.180005, 21.436573),
    (100.329101, 20.786122),
    (100.115988, 20.41785),
)

EARTH_RADIUS_KM = 6371.0088


def is_within_coverage(longitude: float, latitude: float) -> bool:
    """Return whether a coordinate is in Myanmar or within 100 km of it."""
    if not (
        MIN_LONGITUDE <= longitude <= MAX_LONGITUDE
        and MIN_LATITUDE <= latitude <= MAX_LATITUDE
    ):
        return False
    if _point_in_polygon(longitude, latitude):
        return True
    return _distance_to_boundary_km(longitude, latitude) <= COVERAGE_BUFFER_KM


def _point_in_polygon(longitude: float, latitude: float) -> bool:
    inside = False
    for first, second in zip(
        MYANMAR_BOUNDARY,
        (*MYANMAR_BOUNDARY[1:], MYANMAR_BOUNDARY[0]),
        strict=False,
    ):
        first_longitude, first_latitude = first
        second_longitude, second_latitude = second
        if _point_on_segment(
            longitude,
            latitude,
            first_longitude,
            first_latitude,
            second_longitude,
            second_latitude,
        ):
            return True
        if (first_latitude > latitude) != (second_latitude > latitude):
            crossing_longitude = (second_longitude - first_longitude) * (
                latitude - first_latitude
            ) / (second_latitude - first_latitude) + first_longitude
            if longitude < crossing_longitude:
                inside = not inside
    return inside


def _point_on_segment(
    longitude: float,
    latitude: float,
    first_longitude: float,
    first_latitude: float,
    second_longitude: float,
    second_latitude: float,
) -> bool:
    cross_product = (longitude - first_longitude) * (
        second_latitude - first_latitude
    ) - (latitude - first_latitude) * (second_longitude - first_longitude)
    if abs(cross_product) > 1e-9:
        return False
    return (
        min(first_longitude, second_longitude) - 1e-9
        <= longitude
        <= max(first_longitude, second_longitude) + 1e-9
        and min(first_latitude, second_latitude) - 1e-9
        <= latitude
        <= max(first_latitude, second_latitude) + 1e-9
    )


def _distance_to_boundary_km(longitude: float, latitude: float) -> float:
    latitude_radians = math.radians(latitude)
    scale_x = EARTH_RADIUS_KM * math.cos(latitude_radians) * math.pi / 180
    scale_y = EARTH_RADIUS_KM * math.pi / 180

    def project(point: tuple[float, float]) -> tuple[float, float]:
        point_longitude, point_latitude = point
        return (
            (point_longitude - longitude) * scale_x,
            (point_latitude - latitude) * scale_y,
        )

    point = (0.0, 0.0)
    distances = []
    for first, second in zip(
        MYANMAR_BOUNDARY,
        (*MYANMAR_BOUNDARY[1:], MYANMAR_BOUNDARY[0]),
        strict=False,
    ):
        first_x, first_y = project(first)
        second_x, second_y = project(second)
        segment_x = second_x - first_x
        segment_y = second_y - first_y
        segment_length_squared = segment_x**2 + segment_y**2
        if segment_length_squared == 0:
            distances.append(math.hypot(first_x, first_y))
            continue
        projection = (
            (point[0] - first_x) * segment_x + (point[1] - first_y) * segment_y
        ) / segment_length_squared
        projection = max(0.0, min(1.0, projection))
        closest_x = first_x + projection * segment_x
        closest_y = first_y + projection * segment_y
        distances.append(math.hypot(closest_x, closest_y))
    return min(distances)
