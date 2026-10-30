
WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        cs.total_orders, 
        cs.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrderStats cs ON c.c_custkey = cs.c_custkey
    WHERE 
        cs.order_rank <= 3
),
NationWithSupplierCounts AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    nc.n_name,
    pci.p_name,
    pci.total_avail_qty,
    pci.avg_supply_cost,
    tc.total_orders,
    tc.total_spent,
    CASE 
        WHEN nc.supplier_count IS NULL THEN 'No Suppliers'
        ELSE CAST(nc.supplier_count AS STRING)
    END AS suppliers_in_nation,
    (
        SELECT 
            COUNT(*) 
        FROM 
            lineitem l
        WHERE 
            l.l_partkey = pci.p_partkey 
            AND l.l_returnflag = 'R'
    ) AS returned_item_count
FROM 
    PartSupplierInfo pci
FULL OUTER JOIN 
    NationWithSupplierCounts nc ON pci.p_partkey = nc.n_nationkey
LEFT JOIN 
    TopCustomers tc ON nc.n_nationkey = tc.c_custkey
WHERE 
    (pci.avg_supply_cost IS NOT NULL AND pci.avg_supply_cost > 10.00) 
    OR (tc.total_orders > 5 AND tc.total_spent IS NULL)
ORDER BY 
    nc.n_name ASC, 
    pci.p_name DESC;
