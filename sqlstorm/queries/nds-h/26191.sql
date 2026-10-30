WITH SupplierParts AS (
    SELECT s.s_name, p.p_name, p.p_type, 
           CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Type: ', p.p_type) AS detailed_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), RegionNation AS (
    SELECT r.r_name AS region_name, n.n_name AS nation_name, 
           CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS region_nation_info
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
), CustomerOrders AS (
    SELECT c.c_name, o.o_orderkey, 
           CONCAT('Customer: ', c.c_name, ' | OrderKey: ', o.o_orderkey) AS customer_order_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT sp.detailed_info, rn.region_nation_info, co.customer_order_info
FROM SupplierParts sp
JOIN RegionNation rn ON sp.p_type LIKE '%rubber%'
JOIN CustomerOrders co ON sp.p_name LIKE '%widget%'
ORDER BY sp.s_name, rn.region_name;
