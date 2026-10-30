
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 1
),
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        CASE 
            WHEN p.p_size > 10 THEN 'Large'
            WHEN p.p_size BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Small'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2
        )
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    FLOOR(RANDOM() * 100 + 1) AS random_sample,
    ROW_NUMBER() OVER (PARTITION BY tp.size_category ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    CustomerSpending cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
JOIN 
    TopProducts tp ON l.l_partkey = tp.p_partkey
LEFT JOIN 
    PartSupplierDetails psd ON tp.p_partkey = psd.ps_partkey
WHERE 
    o.o_orderdate = (
        SELECT MAX(o2.o_orderdate) FROM orders o2
    ) AND 
    (c.c_acctbal IS NOT NULL OR c.c_comment IS NOT NULL)
GROUP BY 
    c.c_name, tp.size_category
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    tp.size_category, total_revenue DESC
LIMIT 10;
