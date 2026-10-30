WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineExtended AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS extended_price_after_discount,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS total_returns
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name AS supplier_name,
    sd.region,
    COALESCE(cd.c_name, 'No Orders') AS customer_name,
    COALESCE(cd.total_orders, 0) AS total_orders,
    COALESCE(cd.total_spent, 0) AS total_spent,
    COALESCE(ole.extended_price_after_discount, 0) AS extended_price_after_discount,
    ole.total_returns
FROM 
    SupplierDetails sd
LEFT JOIN 
    CustomerOrders cd ON sd.s_suppkey = cd.c_custkey
LEFT JOIN 
    OrderLineExtended ole ON cd.total_orders = ole.o_orderkey
WHERE 
    sd.total_parts_supplied > 10 
    AND (cd.total_spent > 500 OR cd.total_orders > 5)
ORDER BY 
    sd.total_parts_supplied DESC, 
    cd.total_spent DESC, 
    sd.s_name ASC;
