WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        ROUND(p.p_retailprice, 2) AS rounded_price,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_description
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 100
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        pp.p_partkey,
        pp.part_description
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN processed_parts pp ON ps.ps_partkey = pp.p_partkey
    WHERE s.s_acctbal > 10000.00
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_nationkey,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        CONCAT(c.c_name, ' placed an order totaling $', ROUND(o.o_totalprice, 2)) AS order_summary
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 200.00
)
SELECT 
    rp.p_partkey,
    rp.part_description,
    sp.s_name,
    co.o_orderkey,
    co.order_summary
FROM supplier_parts sp
JOIN processed_parts rp ON sp.p_partkey = rp.p_partkey
JOIN customer_orders co ON sp.s_nationkey = co.c_nationkey
ORDER BY rp.p_partkey, co.o_orderkey;
