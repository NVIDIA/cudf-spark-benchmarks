WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
), RankedSuppliers AS (
    SELECT 
        sp.s_suppkey, 
        sp.s_name, 
        sp.p_partkey, 
        sp.p_name, 
        sp.ps_availqty, 
        sp.ps_supplycost, 
        RANK() OVER (PARTITION BY sp.p_partkey ORDER BY sp.ps_supplycost ASC) AS rank 
    FROM 
        SupplierParts sp 
), TopSuppliers AS (
    SELECT 
        r.*, 
        ROW_NUMBER() OVER (ORDER BY ps_supplycost) as row_num 
    FROM 
        RankedSuppliers r 
    WHERE 
        r.rank = 1 
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
), FinalResults AS (
    SELECT 
        cs.c_custkey, 
        cs.c_name, 
        cs.o_orderkey, 
        cs.o_totalprice, 
        ts.s_suppkey, 
        ts.s_name, 
        ts.p_partkey, 
        ts.p_name, 
        ts.ps_availqty 
    FROM 
        CustomerOrders cs 
    JOIN 
        TopSuppliers ts ON cs.o_orderkey = ts.p_partkey 
)
SELECT 
    f.c_custkey, 
    f.c_name, 
    f.o_orderkey, 
    f.o_totalprice, 
    f.s_suppkey, 
    f.s_name, 
    f.p_partkey, 
    f.p_name, 
    SUM(f.ps_availqty) AS total_availqty 
FROM 
    FinalResults f 
GROUP BY 
    f.c_custkey, 
    f.c_name, 
    f.o_orderkey, 
    f.o_totalprice, 
    f.s_suppkey, 
    f.s_name, 
    f.p_partkey, 
    f.p_name
ORDER BY 
    total_availqty DESC 
LIMIT 10;
