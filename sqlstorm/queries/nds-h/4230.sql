WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        RANK() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerTotals AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ct.total_spent,
        ct.num_orders,
        RANK() OVER (ORDER BY ct.total_spent DESC) AS customer_rank
    FROM 
        customerTotals ct
    JOIN 
        customer c ON ct.c_custkey = c.c_custkey
    WHERE 
        ct.total_spent IS NOT NULL
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(COALESCE(ps.ps_availqty, 0)) AS total_avail_qty,
        AVG(p.p_retailprice) AS avg_retail_price
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey,
        p.p_name
)
SELECT 
    tc.c_name AS customer_name,
    tc.total_spent,
    ps.p_name AS part_name,
    ps.total_avail_qty,
    CASE 
        WHEN ps.total_avail_qty < 100 THEN 'Low Stock'
        WHEN ps.total_avail_qty BETWEEN 100 AND 500 THEN 'Moderate Stock'
        ELSE 'High Stock'
    END AS stock_status,
    rs.s_name AS top_supplier,
    rs.region_name,
    rs.supplier_rank
FROM 
    TopCustomers tc
LEFT JOIN 
    lineitem l ON tc.c_custkey = l.l_orderkey
LEFT JOIN 
    PartDetails ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.p_partkey = rs.s_suppkey
WHERE 
    tc.customer_rank <= 10
    AND (rs.supplier_rank = 1 OR rs.supplier_rank IS NULL)
ORDER BY 
    tc.total_spent DESC, 
    ps.total_avail_qty DESC;
