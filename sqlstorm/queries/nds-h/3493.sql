
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(sc.supplier_count, 0) AS suppliers,
    MIN(ro.o_totalprice) AS min_order_total,
    STRING_AGG(DISTINCT CAST(cs.c_custkey AS STRING), ', ') AS high_spenders
FROM 
    part p
LEFT JOIN 
    SupplierCount sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN 
    CustomerSpending cs ON o.o_custkey = cs.c_custkey
WHERE 
    (l.l_shipdate IS NOT NULL AND l.l_shipdate < DATE '1998-10-01')
    OR (l.l_shipdate IS NULL AND l.l_returnflag = 'R')
GROUP BY 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    sc.supplier_count
ORDER BY 
    p.p_partkey;
