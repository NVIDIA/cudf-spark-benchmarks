
WITH SupplyCostSummary AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost) AS total_supply_cost,
        COUNT(ps_suppkey) AS supplier_count
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
CustomerOrderStats AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
TopProducts AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate <= DATE '1996-12-31'
    GROUP BY 
        l.l_partkey
    ORDER BY 
        revenue DESC
    LIMIT 10
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(scs.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(cos.order_count, 0) AS order_count,
    COALESCE(cos.total_spent, 0) AS total_spent,
    tp.revenue,
    CASE 
        WHEN cos.total_spent IS NULL OR cos.total_spent = 0 THEN 'No Purchases'
        ELSE 'Purchased'
    END AS purchase_status
FROM 
    part p
LEFT JOIN 
    SupplyCostSummary scs ON p.p_partkey = scs.ps_partkey
LEFT JOIN 
    CustomerOrderStats cos ON p.p_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')))
LEFT JOIN 
    TopProducts tp ON p.p_partkey = tp.l_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    p.p_brand, 
    tp.revenue DESC NULLS LAST;
