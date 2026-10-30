WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
PartStatistics AS (
    SELECT
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS return_quantity
    FROM
        part p
    LEFT JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY
        p.p_partkey
),
CustomerAgg AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
FinalStats AS (
    SELECT
        p.p_partkey,
        ps.supplier_count,
        ps.avg_supply_cost,
        CASE WHEN ps.supplier_count = 0 THEN NULL ELSE ps.return_quantity / ps.supplier_count END AS avg_return_quantity,
        COALESCE(ca.order_count, 0) AS customer_order_count,
        COALESCE(ca.total_spent, 0) AS customer_total_spent
    FROM
        PartStatistics ps
    JOIN
        part p ON p.p_partkey = ps.p_partkey
    LEFT JOIN
        CustomerAgg ca ON ca.order_count > 0
    WHERE
        (ps.avg_supply_cost IS NULL OR ps.avg_supply_cost > 0) 
        AND (ps.supplier_count > 1 OR ps.return_quantity > 100)
)
SELECT 
    r.r_name, 
    SUM(fs.customer_total_spent) AS total_revenue,
    AVG(fs.avg_supply_cost) AS avg_cost,
    MAX(fs.avg_return_quantity) AS max_return_quantity
FROM 
    FinalStats fs
LEFT JOIN 
    RankedSuppliers rs ON fs.p_partkey = rs.s_suppkey
JOIN 
    nation n ON rs.s_suppkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'N%' 
GROUP BY 
    r.r_name
HAVING 
    SUM(fs.customer_total_spent) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 5;
