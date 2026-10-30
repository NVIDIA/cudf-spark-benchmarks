
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    r.p_retailprice,
    ss.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.avg_supply_cost,
    o.total_revenue,
    COALESCE((SELECT COUNT(DISTINCT c.c_custkey) 
              FROM customer c 
              WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')), 0) AS us_customer_count
FROM 
    RankedParts r
LEFT JOIN 
    SupplierStats ss ON r.p_partkey = ss.s_suppkey
LEFT JOIN 
    OrderStats o ON r.p_partkey = o.o_orderkey
WHERE 
    r.price_rank <= 5
AND 
    (ss.avg_supply_cost IS NULL OR ss.avg_supply_cost < 100.00)
ORDER BY 
    r.p_retailprice DESC, ss.total_available_quantity DESC;
