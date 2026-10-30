WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand, p.p_type, p.p_size
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(od.order_value) AS total_order_value,
    SUM(sp.total_cost) AS total_suppliers_cost,
    AVG(od.order_value) AS avg_order_value,
    MAX(od.order_value) AS max_order_value,
    MIN(od.order_value) AS min_order_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    RankedOrders ro ON c.c_custkey = ro.o_orderkey
LEFT JOIN 
    OrderDetails od ON ro.o_orderkey = od.o_orderkey
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey = (
        SELECT 
            ps_partkey
        FROM 
            partsupp
        WHERE 
            ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp)
        LIMIT 1
    )
WHERE 
    c.c_acctbal IS NOT NULL
    AND (LOWER(c.c_name) LIKE '%corp%' OR c.c_mktsegment = 'BUILDING')
GROUP BY 
    r.r_name
ORDER BY 
    total_order_value DESC;