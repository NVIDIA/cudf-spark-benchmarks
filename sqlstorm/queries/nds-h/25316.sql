WITH SupplierPartDetails AS (
    SELECT s.s_name, p.p_name, p.p_brand, p.p_type, p.p_size, 
           CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_info,
           CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RegionNationDetails AS (
    SELECT r.r_name AS region_name, n.n_name AS nation_name, 
           CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS region_nation_info
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
),
CustomerOrderDetails AS (
    SELECT c.c_name, o.o_orderkey, o.o_orderdate, 
           CONCAT('Order ID: ', o.o_orderkey, ', Customer: ', c.c_name, ', Date: ', o.o_orderdate) AS order_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
AggregatedDetails AS (
    SELECT spd.part_info, spd.supplier_info, rnd.region_nation_info, cod.order_info
    FROM SupplierPartDetails spd
    JOIN RegionNationDetails rnd ON TRUE
    JOIN CustomerOrderDetails cod ON TRUE
)
SELECT part_info, supplier_info, region_nation_info, order_info
FROM AggregatedDetails
WHERE supplier_info LIKE '%California%'
AND region_nation_info LIKE '%Europe%'
ORDER BY part_info, supplier_info;
