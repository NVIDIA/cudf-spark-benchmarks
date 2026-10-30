WITH RankedSales AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
),
TopSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        RankedSales rs ON ps.ps_partkey = rs.l_partkey
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
),
CustomerPriorities AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        CASE 
            WHEN c.c_acctbal > 10000 THEN 'High'
            WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS cust_priority
    FROM 
        customer c
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(COUNT(DISTINCT cu.c_custkey), 0) AS customer_count,
    SUM(COALESCE(ts.total_supply_cost, 0)) AS total_cost,
    AVG(COALESCE(ts.ps_availqty, 0)) AS avg_avail_qty
FROM 
    nation n
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerPriorities cu ON n.n_nationkey = cu.c_custkey
FULL OUTER JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.ps_suppkey
WHERE 
    r.r_name NOT LIKE '%North%'
    AND (ts.total_supply_cost IS NOT NULL OR cu.cust_priority = 'High')
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(COALESCE(ts.total_supply_cost, 0)) > (SELECT AVG(total_supply_cost) FROM TopSuppliers)
    OR n.n_name IS NULL
ORDER BY 
    n.n_name DESC NULLS LAST;