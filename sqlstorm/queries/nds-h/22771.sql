
WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
SupplierAvailability AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
InventoryStock AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS stock_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    COALESCE(co.c_name, 'Unknown Customer') AS customer_name,
    tc.total_spent,
    li.l_orderkey,
    li.l_partkey,
    li.l_quantity,
    li.l_extendedprice,
    CASE 
        WHEN li.l_discount > 0 THEN 'Discounted'
        ELSE 'Regular Price'
    END AS pricing_status,
    COUNT(DISTINCT s.s_suppkey) FILTER (WHERE sa.total_avail_qty > 0) AS active_suppliers
FROM 
    CustomerOrders co
JOIN 
    TopCustomers tc ON co.c_custkey = tc.c_custkey
JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
LEFT JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
LEFT JOIN 
    SupplierAvailability sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN 
    InventoryStock ist ON li.l_partkey = ist.p_partkey
WHERE 
    li.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
AND 
    COALESCE(ist.stock_quantity, 0) > (
        SELECT 
            AVG(stock_quantity) 
        FROM 
            InventoryStock
    )
GROUP BY 
    co.c_custkey, co.c_name, tc.total_spent, li.l_orderkey, li.l_partkey, li.l_quantity, li.l_extendedprice, li.l_discount
HAVING 
    SUM(li.l_quantity) > 100
ORDER BY 
    tc.total_spent DESC, customer_name;
