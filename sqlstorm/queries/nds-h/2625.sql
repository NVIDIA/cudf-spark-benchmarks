
WITH Supplier_Stats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_by_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
Top_Suppliers AS (
    SELECT 
        s_name, 
        total_supply_cost, 
        avg_avail_qty
    FROM 
        Supplier_Stats
    WHERE 
        rank_by_cost <= 3
),
Customer_Orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cu.c_name AS customer_name,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    cu.total_orders AS total_order_value,
    ts.avg_avail_qty AS average_availability,
    ts.total_supply_cost AS total_supply_cost,
    CASE 
        WHEN ts.total_supply_cost IS NULL THEN 'Supplier Info Not Available' 
        ELSE 'Supplier Info Available' 
    END AS supplier_info_status
FROM 
    Customer_Orders cu
LEFT JOIN 
    Top_Suppliers ts ON cu.c_custkey = (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey IN (
            SELECT l.l_orderkey 
            FROM lineitem l 
            WHERE l.l_partkey IN (
                SELECT p.p_partkey 
                FROM part p 
                WHERE p.p_size > 10
            )
        ) 
        LIMIT 1
    )
ORDER BY 
    cu.total_orders DESC, 
    supplier_info_status;
