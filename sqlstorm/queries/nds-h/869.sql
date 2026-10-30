WITH RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
CombinedStats AS (
    SELECT 
        rs.r_name,
        cs.order_count,
        cs.total_spent,
        rs.total_acctbal,
        rs.total_supply_cost,
        RANK() OVER (PARTITION BY rs.r_name ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        RegionStats rs
    LEFT JOIN 
        CustomerOrderStats cs ON rs.nation_count = cs.c_nationkey
)
SELECT 
    r_name,
    order_count,
    total_spent,
    total_acctbal,
    total_supply_cost,
    spending_rank
FROM 
    CombinedStats
WHERE 
    (order_count IS NULL OR order_count > 0) 
    AND (total_spent IS NOT NULL AND total_spent > 10000) 
ORDER BY 
    total_supply_cost DESC, spending_rank;
