
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name,
    ss.s_name,
    ss.total_avail_qty,
    ss.total_supply_cost,
    cs.total_spent,
    cs.order_count,
    lis.total_line_items,
    lis.total_amount
FROM 
    SupplierStats ss
JOIN 
    CustomerStats cs ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_mfgr = 'ManufacturerA'
        )
    )
JOIN 
    LineItemStats lis ON cs.total_spent > 10000 AND lis.total_line_items > 5
WHERE 
    ss.total_supply_cost > 10000
ORDER BY 
    cs.total_spent DESC, ss.total_avail_qty ASC
LIMIT 50;
