
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
AggPartSupp AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(o.order_count, 0) AS customer_order_count,
    a.total_avail_qty,
    r.price_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierInfo s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    RankedOrders r ON p.p_partkey = r.o_orderkey
LEFT JOIN 
    CustomerOrders o ON p.p_partkey = o.c_custkey
LEFT JOIN 
    AggPartSupp a ON p.p_partkey = a.ps_partkey
WHERE 
    p.p_size > 20 
    AND (r.price_rank IS NULL OR r.price_rank <= 5)
ORDER BY 
    p.p_retailprice DESC, 
    a.total_avail_qty ASC;
