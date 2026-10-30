WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
EnhancedData AS (
    SELECT sp.s_name AS supplier_name, sp.p_name AS part_name, 
           co.c_name AS customer_name, co.o_orderdate AS order_date,
           TRIM(UPPER(sp.p_name)) AS processed_part_name,
           CONCAT(sp.s_name, ' - ', co.c_name) AS combined_names,
           ROUND(sp.p_retailprice * (1 - COALESCE(NULLIF(sp.ps_supplycost, 0), 1)), 2) AS adjusted_price
    FROM SupplierParts sp
    JOIN CustomerOrders co ON COALESCE(SUBSTRING(sp.s_name, 1, 3), '') = COALESCE(SUBSTRING(co.c_name, 1, 3), '')
)
SELECT supplier_name, part_name, customer_name, order_date, processed_part_name, combined_names, adjusted_price
FROM EnhancedData
WHERE adjusted_price > 20.00
ORDER BY order_date DESC, supplier_name ASC;
