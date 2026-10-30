WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(AVG(l.l_discount), 0) AS avg_discount
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
HighValueOrders AS (
    SELECT 
        co.c_custkey,
        co.o_orderkey,
        co.o_totalprice,
        pd.p_name,
        pd.avg_discount,
        ROW_NUMBER() OVER (ORDER BY co.o_totalprice DESC) AS order_rank
    FROM 
        CustomerOrders co
    JOIN 
        lineitem li ON co.o_orderkey = li.l_orderkey
    JOIN 
        PartDetails pd ON li.l_partkey = pd.p_partkey
    WHERE 
        pd.p_retailprice > 100 AND
        co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    n.n_name,
    SUM(hv.o_totalprice) AS total_high_value_sales,
    COUNT(DISTINCT hv.o_orderkey) AS total_orders,
    MIN(hv.avg_discount) AS min_discount,
    MAX(hv.avg_discount) AS max_discount
FROM 
    HighValueOrders hv 
JOIN 
    customer c ON hv.c_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
HAVING 
    SUM(hv.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
ORDER BY 
    total_high_value_sales DESC;
