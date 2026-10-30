WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
),
OrderLineDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_amount,
        COUNT(l.l_linenumber) AS line_count,
        SUM(CASE WHEN l.l_tax > 0 THEN l.l_tax ELSE 0 END) AS total_tax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
RankedOrders AS (
    SELECT 
        o.c_custkey, 
        o.total_spent,
        ROW_NUMBER() OVER (PARTITION BY o.c_custkey ORDER BY o.total_spent DESC) AS order_rank
    FROM 
        CustomerOrders o
)
SELECT 
    r.r_name,
    s.s_name,
    COALESCE(ss.total_available, 0) AS total_available_parts,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    co.c_name,
    co.order_count,
    co.total_spent,
    od.total_line_amount,
    od.line_count,
    od.total_tax
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders co ON s.s_suppkey = co.c_custkey
LEFT JOIN 
    OrderLineDetails od ON co.order_count > 0
WHERE 
    (ss.total_available > 100 OR co.total_spent IS NOT NULL)
    AND r.r_name LIKE 'N%'
ORDER BY 
    r.r_name, co.total_spent DESC
LIMIT 100;
