WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_supplycost, 
        ps.ps_availqty 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Spent 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate 
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(co.Total_Spent) AS Total_Amount 
    FROM 
        CustomerOrders co 
    JOIN 
        customer c ON co.c_custkey = c.c_custkey 
    GROUP BY 
        c.c_custkey, c.c_name 
    ORDER BY 
        Total_Amount DESC 
    LIMIT 10 
)
SELECT 
    tp.c_name, 
    sp.p_name, 
    SUM(sp.ps_availqty) AS Total_Available_Qty, 
    AVG(sp.ps_supplycost) AS Avg_Supply_Cost 
FROM 
    SupplierParts sp 
JOIN 
    TopCustomers tp ON tp.c_custkey = sp.s_suppkey 
GROUP BY 
    tp.c_name, sp.p_name 
HAVING 
    SUM(sp.ps_availqty) > 50 
ORDER BY 
    Avg_Supply_Cost DESC;