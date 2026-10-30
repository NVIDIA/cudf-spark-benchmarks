
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
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
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_supply_cost,
        part_count,
        ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierSummary s
    WHERE 
        total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierSummary)
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_orders,
    co.total_spent,
    rs.supplier_rank,
    rs.s_name AS top_supplier
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedSuppliers rs ON co.c_custkey = (
        SELECT c.c_custkey
        FROM orders o 
        JOIN customer c ON o.o_custkey = c.c_custkey
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_returnflag = 'N' 
          AND l.l_shipmode = 'AIR'
        GROUP BY c.c_custkey
        ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC
        LIMIT 1
    )
WHERE 
    co.total_spent > 1000
ORDER BY 
    co.total_orders DESC, co.total_spent DESC;
