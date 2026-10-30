WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01'
        AND o.o_orderdate < '1997-01-01'
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierAsOfLastMonth AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
        AND ps.ps_supplycost IS NOT NULL
),
Final AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        c.c_name,
        r.r_name
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name IS NOT NULL 
        AND l.l_tax < 0.05
    GROUP BY 
        l.l_orderkey, c.c_name, r.r_name
)
SELECT 
    fo.l_orderkey,
    fo.revenue,
    COALESCE(cs.total_spent, 0) AS customer_spending,
    CASE 
        WHEN fo.revenue > (SELECT AVG(revenue) FROM Final) 
        THEN 'High Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category,
    MAX(ro.o_orderdate) AS latest_order_date
FROM 
    Final fo
LEFT JOIN 
    CustomerSpending cs ON fo.c_name = cs.c_name
LEFT JOIN 
    RankedOrders ro ON fo.l_orderkey = ro.o_orderkey AND ro.rank = 1
WHERE 
    fo.revenue IS NOT NULL
    AND cs.total_spent IS NULL OR cs.total_spent > 10000
GROUP BY 
    fo.l_orderkey, fo.revenue, cs.total_spent, fo.c_name
ORDER BY 
    fo.revenue DESC NULLS LAST;