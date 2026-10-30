
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CombinedStats AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.nation,
        os.o_orderkey,
        os.o_orderdate,
        ss.total_supply_cost,
        os.total_revenue,
        (ss.total_supply_cost / NULLIF(os.total_revenue, 0)) AS cost_to_revenue_ratio
    FROM 
        SupplierStats ss
    LEFT JOIN 
        OrderStats os ON ss.s_suppkey = (
            SELECT ps.ps_suppkey
            FROM partsupp ps
            WHERE ps.ps_partkey IN (
                SELECT DISTINCT l.l_partkey
                FROM lineitem l
                JOIN orders o ON l.l_orderkey = o.o_orderkey
                WHERE o.o_orderdate >= DATE '1997-01-01'
            )
            LIMIT 1
        )
)
SELECT 
    s.s_suppkey,
    s.s_name,
    s.nation,
    s.total_supply_cost,
    s.o_orderdate,
    s.total_revenue,
    s.cost_to_revenue_ratio
FROM 
    CombinedStats s
JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
ORDER BY 
    s.total_supply_cost DESC, 
    s.total_revenue DESC
LIMIT 100;
