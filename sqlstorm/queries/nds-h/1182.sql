WITH supplier_totals AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ranked_suppliers AS (
    SELECT
        st.s_suppkey,
        st.s_name,
        st.total_cost,
        st.part_count,
        RANK() OVER (ORDER BY st.total_cost DESC) AS rank
    FROM 
        supplier_totals st
),
ranked_customers AS (
    SELECT
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.order_count,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        customer_orders co
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_spent AS customer_spent,
    ss.s_name AS supplier_name,
    ss.total_cost AS supplier_cost
FROM 
    ranked_customers cs
INNER JOIN 
    orders o ON cs.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    ranked_suppliers ss ON li.l_suppkey = ss.s_suppkey
WHERE 
    cs.rank <= 10 
    AND ss.rank <= 10
    AND (cs.total_spent IS NOT NULL OR ss.total_cost IS NOT NULL)
ORDER BY 
    cs.total_spent DESC, ss.total_cost DESC;
