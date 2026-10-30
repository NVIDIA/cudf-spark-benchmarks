
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT 
        c.c_custkey AS custkey,
        c.c_name AS name,
        c.total_spent,
        c.order_count,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrders c
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
SalesData AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    tc.name,
    tc.total_spent,
    tc.order_count,
    sp.total_avail_qty,
    sp.supplier_count,
    SUM(sd.revenue) AS total_revenue
FROM 
    TopCustomers tc
JOIN 
    SalesData sd ON tc.custkey = sd.l_orderkey
JOIN 
    SupplierParts sp ON sd.l_partkey = sp.ps_partkey
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.name, tc.total_spent, tc.order_count, sp.total_avail_qty, sp.supplier_count
ORDER BY 
    total_revenue DESC;
