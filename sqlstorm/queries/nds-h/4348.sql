WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_fulfilled,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    co.total_orders,
    co.total_fulfilled,
    co.avg_order_value,
    ss.part_count,
    AVG(RankOrders.o_totalprice) AS avg_order_price_by_status
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customerorders co ON n.n_nationkey = co.c_custkey
LEFT JOIN 
    supplierstats ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20)
        LIMIT 1
    )
LEFT JOIN 
    RankedOrders RankOrders ON RankOrders.o_orderkey = co.total_orders
WHERE 
    ss.total_supply_cost IS NOT NULL 
    AND co.total_orders > 5
GROUP BY 
    r.r_name, co.total_orders, co.total_fulfilled, co.avg_order_value, ss.part_count
ORDER BY 
    r.r_name;