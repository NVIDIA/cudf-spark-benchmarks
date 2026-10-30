WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerOrders AS (
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
), LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        SUM(l.l_extendedprice) AS total_price,
        SUM(l.l_discount) AS total_discount,
        SUM(l.l_tax) AS total_tax
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    ss.s_name,
    ss.total_available_qty,
    ss.avg_supply_cost,
    lid.unique_parts,
    lid.total_price,
    lid.total_discount,
    lid.total_tax
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON (ss.part_count > 5 AND ss.total_available_qty IS NOT NULL)
LEFT JOIN 
    LineItemDetails lid ON lid.l_orderkey = cs.c_custkey
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders WHERE order_count > 2)
ORDER BY 
    cs.total_spent DESC, ss.avg_supply_cost ASC
LIMIT 5 OFFSET 10;