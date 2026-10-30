WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
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
    WHERE 
        o.o_orderstatus = 'O' AND (o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31')
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_parts,
        total_available_qty,
        total_cost,
        RANK() OVER (ORDER BY total_cost DESC) AS supplier_rank
    FROM 
        SupplierStats s
    WHERE 
        total_parts > 5
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_orders,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
    WHERE 
        total_orders > 2
)
SELECT 
    r_s.supplier_rank,
    r_c.customer_rank,
    r_s.s_name AS supplier_name,
    r_c.c_name AS customer_name,
    r_s.total_parts,
    r_s.total_available_qty,
    r_s.total_cost,
    r_c.total_orders,
    r_c.total_spent
FROM 
    RankedSuppliers r_s
FULL OUTER JOIN 
    RankedCustomers r_c ON r_s.supplier_rank = r_c.customer_rank
WHERE 
    (r_s.total_cost IS NOT NULL OR r_c.total_spent IS NOT NULL)
ORDER BY 
    COALESCE(r_s.supplier_rank, r_c.customer_rank);