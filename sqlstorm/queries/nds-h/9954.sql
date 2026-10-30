WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_quantity, 
        AVG(ps.ps_supplycost) AS average_supply_cost, 
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= '1997-01-01' 
        AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
), CustomerStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(os.total_revenue) AS total_revenue,
        COUNT(DISTINCT os.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        OrderStats os ON c.c_custkey = os.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_revenue,
    cs.order_count,
    ss.total_available_quantity,
    ss.average_supply_cost,
    ss.part_count
FROM 
    CustomerStats cs
JOIN 
    SupplierStats ss ON cs.total_revenue > 10000
ORDER BY 
    cs.total_revenue DESC, ss.part_count DESC
LIMIT 100;