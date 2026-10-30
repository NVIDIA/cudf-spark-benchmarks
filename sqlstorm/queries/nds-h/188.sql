WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS num_line_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.total_order_value) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        OrderStats o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSummary AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(cos.total_spent) AS region_total_spent,
        COUNT(DISTINCT cos.c_custkey) AS customer_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrderSummary cos ON c.c_custkey = cos.c_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    rs.r_name,
    rs.region_total_spent,
    rs.customer_count,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    AVG(ss.num_parts) AS avg_parts_per_supplier
FROM 
    RegionSummary rs
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2
        )
    )
GROUP BY 
    rs.r_name, rs.region_total_spent, rs.customer_count
ORDER BY 
    rs.region_total_spent DESC;
