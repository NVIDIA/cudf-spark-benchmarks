WITH  Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Filtered_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_available_quantity,
        ss.total_supply_cost,
        ss.total_orders
    FROM 
        supplier s
    JOIN 
        Supplier_Summary ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_orders IS NOT NULL AND ss.total_orders > (
            SELECT 
                AVG(total_orders) 
            FROM 
                Supplier_Summary
        )
)
SELECT 
    fs.s_suppkey,
    fs.s_name,
    fs.total_available_quantity,
    COALESCE(fs.total_supply_cost / NULLIF(fs.total_orders, 0), 0) AS avg_supply_cost_per_order,
    CASE 
        WHEN fs.total_available_quantity > (SELECT MAX(total_available_quantity) FROM Filtered_Suppliers) - 10 
        THEN 'High availability'
        ELSE 'Low availability' 
    END AS availability_status,
    CONCAT('Supplier ', fs.s_name, ' has an average supply cost of ', COALESCE(CAST(fs.total_supply_cost AS VARCHAR(10)), '0.00'), 
           ' per order.')
FROM 
    Filtered_Suppliers fs
LEFT JOIN 
    region r ON r.r_regionkey = (
        SELECT 
            n.n_regionkey 
        FROM 
            nation n 
        WHERE 
            n.n_nationkey = (
                SELECT 
                    c.c_nationkey 
                FROM 
                    customer c 
                WHERE 
                    c.c_custkey = (
                        SELECT 
                            o.o_custkey 
                        FROM 
                            orders o 
                        WHERE 
                            o.o_orderkey = (
                                SELECT 
                                    l.l_orderkey 
                                FROM 
                                    lineitem l 
                                WHERE 
                                    l.l_returnflag = 'R' 
                                ORDER BY 
                                    l.l_shipdate DESC 
                                LIMIT 1
                            )
                    )
            )
    )
ORDER BY 
    fs.total_orders DESC
LIMIT 10;
