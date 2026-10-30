WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
NationalSupply AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    INNER JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NULL OR COUNT(o.o_orderkey) > 0
),
LineItemAnalysis AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        AVG(li.l_quantity) AS avg_quantity,
        COUNT(CASE WHEN li.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        li.l_orderkey
)
SELECT 
    np.n_name AS nation_name,
    cp.c_name AS customer_name,
    pp.p_name AS part_name,
    ls.total_sales,
    ls.avg_quantity,
    np.total_supply_cost,
    cp.order_count
FROM 
    NationalSupply np
FULL OUTER JOIN 
    CustomerOrders cp ON np.n_nationkey = cp.c_custkey
LEFT JOIN 
    RankedParts pp ON pp.rnk = 1
JOIN 
    LineItemAnalysis ls ON ls.l_orderkey = cp.c_custkey
WHERE 
    (np.total_supply_cost IS NOT NULL OR cp.order_count > 0) 
    AND (pp.p_retailprice IS NOT NULL OR ls.total_sales > 1000)
ORDER BY 
    np.n_name, cp.c_name, ls.total_sales DESC
LIMIT 100 OFFSET 0;