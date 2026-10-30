
WITH ranked_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
lineitem_analysis AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS item_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)

SELECT 
    rc.c_name,
    rc.total_spent,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    la.revenue AS item_revenue
FROM 
    ranked_customers rc
LEFT JOIN 
    supplier_summary ss ON rc.rank = (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s)
LEFT JOIN 
    lineitem_analysis la ON rc.c_custkey = la.l_orderkey
WHERE 
    (rc.total_spent > 10000 OR ss.total_supply_cost IS NOT NULL)
    AND (la.item_rank IS NULL OR la.item_rank <= 5)
ORDER BY 
    rc.total_spent DESC, ss.total_supply_cost ASC;
