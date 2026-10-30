
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(*) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(*) > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
NullHandlingTest AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(NULLIF(SUM(l.l_quantity), 0), 1) AS total_sold
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) IS NULL OR COALESCE(SUM(l.l_quantity), 0) > 100
)
SELECT 
    corders.c_name AS Customer_Name,
    sdetails.s_name AS Supplier_Name,
    rorders.o_orderkey AS Order_Key,
    n.n_name AS Nation_Name,
    sdetails.total_parts AS Supplier_Part_Count,
    nth.total_sold AS Part_Total_Sold
FROM 
    CustomerOrders corders
JOIN 
    RankedOrders rorders ON corders.order_count > 5 AND rorders.o_orderstatus = 'F'
LEFT JOIN 
    SupplierDetails sdetails ON rorders.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_returnflag = 'N')
LEFT JOIN 
    NullHandlingTest nth ON sdetails.total_supply_cost > 5000
JOIN 
    nation n ON corders.c_custkey = n.n_nationkey
WHERE 
    sdetails.total_supply_cost IS NOT NULL
ORDER BY 
    corders.total_spent DESC, rorders.o_orderdate ASC;
