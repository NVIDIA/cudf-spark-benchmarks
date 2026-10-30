
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sd.s_name, 'Unknown') AS supplier_name,
    COALESCE(cd.order_count, 0) AS customer_order_count,
    COALESCE(ps.total_orders, 0) AS part_order_count,
    ps.total_sales,
    sd.total_supply_cost AS supplier_cost,
    sd.supplier_rank
FROM 
    part p
LEFT JOIN 
    partsupp psup ON p.p_partkey = psup.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON psup.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    PartSales ps ON p.p_partkey = ps.l_partkey
LEFT JOIN 
    CustomerOrders cd ON cd.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'USA'
        )
    )
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) 
                        FROM part p2) 
ORDER BY 
    ps.total_sales DESC NULLS LAST;
