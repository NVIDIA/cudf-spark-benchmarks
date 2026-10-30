WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized' 
            ELSE 'Pending' 
        END AS order_status,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
) 
SELECT 
    rs.s_suppkey,
    rs.s_name,
    os.o_orderkey,
    os.order_status,
    cs.c_custkey,
    cs.c_name,
    cs.total_spent,
    cs.orders_count,
    cs.last_order_date,
    COALESCE(rs.total_supply_value, 0) AS total_supplied_value
FROM 
    RankedSuppliers rs
FULL OUTER JOIN 
    OrdersSummary os ON rs.s_suppkey = os.o_orderkey
FULL OUTER JOIN 
    CustomerOrders cs ON os.o_orderkey = cs.c_custkey
WHERE 
    (rs.s_suppkey IS NOT NULL OR os.o_orderkey IS NOT NULL OR cs.c_custkey IS NOT NULL)
    AND (cs.total_spent > 1000 OR rs.total_supply_value IS NULL)
ORDER BY 
    rs.s_name, os.o_orderkey, cs.total_spent DESC;
