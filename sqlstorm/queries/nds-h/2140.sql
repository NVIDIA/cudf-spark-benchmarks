
WITH SupplyCost AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name AS region,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(sc.total_supply_cost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplyCost sc ON s.s_suppkey = sc.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name, r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_count,
        o.o_orderstatus,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
SalesSummary AS (
    SELECT 
        od.o_orderstatus,
        COUNT(od.o_orderkey) AS order_count,
        AVG(COALESCE(od.total_price, 0)) AS avg_order_value,
        SUM(od.total_price) AS total_sales
    FROM 
        OrderDetails od
    GROUP BY 
        od.o_orderstatus
)
SELECT 
    ts.s_name,
    ts.region,
    cs.order_count,
    cs.total_spent,
    ss.order_count AS sales_order_count,
    ss.avg_order_value,
    ss.total_sales
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrders cs ON ts.s_suppkey = cs.c_custkey
LEFT JOIN 
    SalesSummary ss ON ts.region = ss.o_orderstatus
WHERE 
    ts.rank <= 5
ORDER BY 
    ts.region, sales_order_count DESC;
