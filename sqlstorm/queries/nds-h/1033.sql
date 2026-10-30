WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationCost AS (
    SELECT 
        n.n_name,
        SUM(ss.total_cost) AS nation_total_cost
    FROM 
        nation n
    LEFT JOIN 
        SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        n.n_name
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS order_count,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        pp.avg_price,
        RANK() OVER (ORDER BY pp.order_count DESC) AS prod_rank
    FROM 
        PopularParts pp
    JOIN 
        part p ON pp.p_partkey = p.p_partkey
    WHERE 
        pp.order_count > 10
)
SELECT 
    n.n_name,
    nc.nation_total_cost,
    tp.p_name,
    tp.avg_price,
    CASE 
        WHEN nc.nation_total_cost IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status
FROM 
    NationCost nc
LEFT JOIN 
    TopProducts tp ON tp.prod_rank <= 5
INNER JOIN 
    nation n ON n.n_name = nc.n_name
ORDER BY 
    nc.nation_total_cost DESC, tp.avg_price DESC;
