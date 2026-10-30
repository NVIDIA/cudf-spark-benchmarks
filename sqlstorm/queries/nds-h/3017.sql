
WITH supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, r.r_name
),
customer_orders AS (
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
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    co.c_name,
    COALESCE(si.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(co.order_count, 0) AS order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    li.total_line_value,
    li.avg_quantity
FROM 
    customer_orders co
FULL OUTER JOIN 
    supplier_info si ON co.c_custkey = si.s_suppkey
FULL OUTER JOIN 
    lineitem_summary li ON co.c_custkey = li.l_orderkey
WHERE 
    (co.order_count > 0 OR si.total_supply_cost IS NOT NULL) 
    AND (li.total_line_value IS NOT NULL OR co.total_spent > 500.00)
ORDER BY 
    total_spent DESC, total_supply_cost ASC;
